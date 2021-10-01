<template>
  <div>
    <h1>{{$globalState.user.name}}</h1>
    <h2>Classes</h2>
    <ul v-if="classes !== null">
      <li v-for="c in classes" :key="c.id">
        #{{c.id}}: {{c.name}}
        <table>
          <tr v-for="(g, index) in c.grades" :key="index">
            <td>{{g[0]}}</td>
            <td>{{g[1]}}</td>
          </tr>
        </table>
      </li>
    </ul>
  </div>
</template>

<script>
export default {
  name: "User",
  data(){
    return{
      classes: null
    }
  },
  async created() {
    if(!this.$globalState.logged) this.$router.go(-1);
    const classIds = await this.$globalState.getClassesId();
    const classes = classIds.map(x => {return {id: x}});
    const promises = [];
    classes.forEach(c => {
      promises.push(new Promise(resolve => {
            this.$globalState.getClassName(c.id).then(name => {
              c.name = name;
              resolve();
            })
      }));
      promises.push(new Promise(resolve => {
        this.$globalState.getClassGrades(c.id).then(grades => {
          c.grades = grades;
          resolve();
        })
      }));
    });
    await Promise.all(promises);
    this.classes = classes;
  }
}
</script>

<style scoped>
table{
  margin: auto;
}
</style>
